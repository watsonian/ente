import Container from 'components/Container';
import styled from 'styled-components';

export const QRCode = styled.img(
    ({ theme }) => `
    height: 200px;
    width: 200px;
    margin: ${theme.spacing(2)};
`
);

export const LoadingQRCode = styled(Container)(
    ({ theme }) => `
    width:200px;
    aspect-ratio:1;
    border: 1px solid ${theme.palette.grey.A200};
    margin: ${theme.spacing(2)};
    `
);
